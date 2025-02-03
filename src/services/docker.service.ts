import Docker from "dockerode";
import path from "path";
import { config } from "../config";
import { AppConfig } from "../types";
import fs from "fs";

export class DockerService {
  private docker: Docker;

  constructor() {
    this.docker = new Docker({ socketPath: "//./pipe/docker_engine" });
  }

  private async streamLogs(container: Docker.Container): Promise<void> {
    const logStream = await container.logs({
      follow: true,
      stdout: true,
      stderr: true,
      timestamps: true,
    });

    // Create a log file for debugging
    const logFile = fs.createWriteStream("docker-build.log", { flags: "a" });

    logStream.on("data", (chunk) => {
      const log = chunk.toString("utf8");
      console.log(log);
      logFile.write(log + "\n");
    });

    return new Promise((resolve) => {
      logStream.on("end", () => {
        logFile.end();
        resolve();
      });
    });
  }
  async buildApp(buildId: string, url: string, appName: string, appConfig: AppConfig): Promise<void> {
    const buildPath = path.resolve(config.buildsDir, buildId);
    let container: Docker.Container | null = null;

    try {
        console.log(`[${buildId}] Starting build process...`);
        await fs.promises.mkdir(buildPath, { recursive: true });

        // Verify Docker daemon is responsive
        try {
            await this.docker.ping();
            console.log(`[${buildId}] Docker daemon is responsive`);
        } catch (error) {
            throw new Error("Docker daemon is not responding");
        }

        console.log(`[${buildId}] Creating container...`);

        container = await this.docker.createContainer({
            Image: "react-native-builder:latest",
            Cmd: ["/bin/bash", "/app/scripts/build-app.sh"],
            HostConfig: {
                Binds: [`${buildPath.replace(/\\/g, "/")}:/app/output`],
                AutoRemove: false,
            },
            Env: [
                `APP_URL=${url}`,
                `APP_NAME=${appName}`,
                `APP_CONFIG=${JSON.stringify(appConfig)}`,
                `BUILD_ID=${buildId}`,
                "DEBIAN_FRONTEND=noninteractive",
            ],
            AttachStdout: true,
            AttachStderr: true,
            Tty: false,
        });

        console.log(`[${buildId}] Starting container and streaming logs...`);
        await container.start();
        await this.streamLogs(container);

        const result = await container.wait();

        if (result.StatusCode !== 0) {
            throw new Error(`Build process exited with code ${result.StatusCode}`);
        }

        console.log(`[${buildId}] Build completed successfully`);
    } catch (error) {
        console.error(`[${buildId}] Build failed:`, error);
        throw new Error(`Docker build failed: ${(error as Error).message}`);
    } finally {
        if (container) {
            try {
                await container.stop();
                await container.remove();
            } catch (cleanupError) {
                console.error(`[${buildId}] Cleanup error:`, cleanupError);
            }
        }
    }
}

}

export const dockerService = new DockerService();
