import { Controller, Post, Body, HttpCode, HttpStatus, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

export class RegisterDto {
  email!: string;
  password!: string;
}

export class LoginDto {
  email!: string;
  password!: string;
}

export class RefreshDto {
  refreshToken!: string;
}

export class LogoutDto {
  userId!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  register(@Body() body: RegisterDto) {
    if (!body?.email || !body?.password) {
      throw new BadRequestException('Email and password are required');
    }
    try {
      return this.authService.register(body.email, body.password);
    } catch (err: any) {
      throw new BadRequestException(err.message || 'Registration failed');
    }
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() body: LoginDto) {
    if (!body?.email || !body?.password) {
      throw new BadRequestException('Email and password are required');
    }
    try {
      return this.authService.login(body.email, body.password);
    } catch (err: any) {
      throw new UnauthorizedException(err.message || 'Invalid credentials');
    }
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() body: RefreshDto) {
    if (!body?.refreshToken) {
      throw new BadRequestException('Refresh token is required');
    }
    try {
      return this.authService.refresh(body.refreshToken);
    } catch (err: any) {
      throw new UnauthorizedException(err.message || 'Invalid refresh token');
    }
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logout(@Body() body: LogoutDto) {
    if (body?.userId) {
      this.authService.logout(body.userId);
    }
    return { success: true };
  }
}
