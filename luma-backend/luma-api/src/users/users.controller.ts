import { Body, Controller, Patch, Req, UseGuards } from '@nestjs/common';

import { AuthGuard } from '../auth/auth.guard.js';

import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { UsersService } from './users.service.js';

@Controller('api/users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Patch('me')
  @UseGuards(AuthGuard)
  updateProfile(
    @Req() request: any,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(
      request.account.id,
      updateProfileDto,
    );
  }
}
