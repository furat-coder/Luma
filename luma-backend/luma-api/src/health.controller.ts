import { Controller, Get } from '@nestjs/common';

@Controller('api/health')
export class HealthController {
  @Get()
  check() {
    return {
      success: true,
      message: 'Luma API is running 🚀',
      service: 'luma-api',
    };
  }
}
