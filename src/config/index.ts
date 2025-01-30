import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
  buildsDir: process.env.BUILDS_DIR || './builds',
} as const;

