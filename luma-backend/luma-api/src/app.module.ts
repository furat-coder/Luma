import { Module } from '@nestjs/common';

import { HealthController } from './health.controller.js';
import { AuthModule } from './auth/auth.module.js';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [AuthModule, UsersModule],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
