export interface AppConfig {
    name: string;
    bundleId?: string;
    version?: string;
    icon?: string;
    splashScreen?: string;
    customSettings?: Record<string, unknown>;
}

export interface BuildRequest {
    url: string;
    appName: string;
    config: AppConfig;
  }
  
  export interface BuildResponse {
    success: boolean;
    buildId: string;
    downloadLinks?: {
      android?: string;
      ios?: string;
    };
    error?: string;
  }
  