import { Controller, Get, HttpCode, HttpStatus } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  @HttpCode(HttpStatus.OK)
  check() {
    return {
      status: 'ok',
      service: 'DayBook Zero-Knowledge Sync & LLM Proxy',
      version: '1.0.0',
      timestamp: Date.now(),
      uptime: process.uptime(),
    };
  }
}

