import express from 'express';
import { promises as fs } from 'fs';
import path from 'path';
import { dockerService } from './services/docker.service';
import { BuildRequest, BuildResponse } from './types';
import { config } from './config';

const app = express();
app.use(express.json());

// Ensure builds directory exists
const ensureBuildsDir = async () => {
  try {
    await fs.mkdir(config.buildsDir, { recursive: true });
  } catch (error) {
    console.error('Failed to create builds directory:', error);
    process.exit(1);
  }
};

app.post('/api/v1/convert', async (req, res) => {
  try {
    const { url, appName, config: appConfig }: BuildRequest = req.body;

    if (!url || !appName) {
      return res.status(400).json({
        success: false,
        error: 'URL and app name are required'
      });
    }

    const buildId = `build-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const buildPath = path.join(config.buildsDir, buildId);
    
   
    await fs.mkdir(buildPath, { recursive: true });
    await dockerService.buildApp(buildId, url, appName, appConfig);

    const response: BuildResponse = {
      success: true,
      buildId,
      downloadLinks: {
        android: `/builds/${buildId}/android/app-release.apk`,
        ios: `/builds/${buildId}/ios/build/App.ipa`
      }
    };

    res.json(response);
  } catch (error) {
    console.error('Build failed:', error);
    res.status(500).json({
      success: false,
      error: 'Build failed'
    });
  }
});

// Endpoint to download build artifacts
app.get('/builds/:buildId/:platform/:file', async (req, res) => {
  const { buildId, platform, file } = req.params;
  const filePath = path.join(config.buildsDir, buildId, platform, file);
  
  try {
    await fs.access(filePath);
    res.download(filePath);
  } catch (error) {
    res.status(404).json({
      success: false,
      error: 'Build file not found'
    });
  }
});


const init = async () => {
  await ensureBuildsDir();
  app.listen(config.port, () => {
    console.log(`Server running on port ${config.port}`);
  });
};

init().catch(console.error);