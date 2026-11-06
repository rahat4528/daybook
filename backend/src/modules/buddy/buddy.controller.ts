import { Controller, Post, Get, Body, Query, HttpCode, HttpStatus, BadRequestException } from '@nestjs/common';
import { BuddyService, BuddyCheckIn } from './buddy.service';

export class GenerateCodeDto {
  userId!: string;
}

export class PairCodeDto {
  userId!: string;
  code!: string;
}

export class PublishCheckInDto {
  userId!: string;
  type!: BuddyCheckIn['type'];
  message!: string;
}

@Controller('buddy')
export class BuddyController {
  constructor(private readonly buddyService: BuddyService) {}

  @Post('code')
  @HttpCode(HttpStatus.OK)
  generateCode(@Body() body: GenerateCodeDto) {
    if (!body?.userId) throw new BadRequestException('userId is required');
    const code = this.buddyService.generatePairingCode(body.userId);
    return { code };
  }

  @Post('pair')
  @HttpCode(HttpStatus.OK)
  pair(@Body() body: PairCodeDto) {
    if (!body?.userId || !body?.code) throw new BadRequestException('userId and code are required');
    try {
      return this.buddyService.pairWithCode(body.userId, body.code);
    } catch (err: any) {
      throw new BadRequestException(err.message || 'Pairing failed');
    }
  }

  @Post('check-in')
  @HttpCode(HttpStatus.CREATED)
  publishCheckIn(@Body() body: PublishCheckInDto) {
    if (!body?.userId || !body?.type || !body?.message) {
      throw new BadRequestException('userId, type, and message are required');
    }
    return this.buddyService.publishCheckIn(body.userId, body.type, body.message);
  }

  @Get('feed')
  @HttpCode(HttpStatus.OK)
  getFeed(@Query('userId') userId: string) {
    if (!userId) throw new BadRequestException('userId query parameter is required');
    return this.buddyService.getBuddyFeed(userId);
  }

  @Post('unpair')
  @HttpCode(HttpStatus.OK)
  unpair(@Body('userId') userId: string) {
    if (!userId) throw new BadRequestException('userId is required');
    const success = this.buddyService.unpair(userId);
    return { success };
  }
}

