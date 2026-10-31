import {
  Body,
  Controller,
  Get,
  Headers,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { AuthService } from './auth.service.js';
import { AuthGuard } from './auth.guard.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { VerifyEmailDto } from './dto/verify-email.dto.js';

@Controller('api/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @Post('verify-email')
  verifyEmail(@Body() verifyEmailDto: VerifyEmailDto) {
    return this.authService.verifyEmail(
      verifyEmailDto.email,
      verifyEmailDto.code,
    );
  }

  @Post('resend-verification')
  resendVerification(@Body('email') email: string) {
    return this.authService.resendVerification(email);
  }

  @Post('login')
  login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Get('me')
  @UseGuards(AuthGuard)
  me(@Req() request: any) {
    const account = request.account;

    return {
      success: true,
      account: {
        id: account.id,
        email: account.email,
        username: account.username,
        displayName: account.displayName,
        profileImage: account.profileImage,
        isVerified: account.isVerified,
        isActive: account.isActive,
      },
    };
  }

  @Post('logout')
  @UseGuards(AuthGuard)
  logout(
    @Headers('authorization')
    authorization: string,
  ) {
    const [, token] = authorization.split(' ');

    return this.authService.logout(token);
  }
}
