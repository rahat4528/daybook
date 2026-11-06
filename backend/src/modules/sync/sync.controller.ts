import { Controller, Post, Get, Body, Query, HttpCode, HttpStatus, BadRequestException } from '@nestjs/common';
import { SyncService, SyncBlobDto } from './sync.service';

export class PushBlobsDto {
  userId!: string;
  deviceId!: string;
  blobs!: SyncBlobDto[];
}

@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  @HttpCode(HttpStatus.OK)
  pushBlobs(@Body() body: PushBlobsDto) {
    if (!body?.userId || !body?.deviceId || !Array.isArray(body?.blobs)) {
      throw new BadRequestException('userId, deviceId, and blobs array are required');
    }
    return this.syncService.pushBlobs(body.userId, body.deviceId, body.blobs);
  }

  @Get('pull')
  @HttpCode(HttpStatus.OK)
  pullBlobs(
    @Query('userId') userId: string,
    @Query('deviceId') deviceId: string,
    @Query('since') since?: string,
    @Query('limit') limit?: string,
  ) {
    if (!userId || !deviceId) {
      throw new BadRequestException('userId and deviceId query parameters are required');
    }
    const sinceTimestamp = since ? parseInt(since, 10) : 0;
    const limitNum = limit ? parseInt(limit, 10) : 100;
    return this.syncService.pullBlobs(userId, deviceId, isNaN(sinceTimestamp) ? 0 : sinceTimestamp, isNaN(limitNum) ? 100 : limitNum);
  }

  @Get('count')
  @HttpCode(HttpStatus.OK)
  getBlobCount(@Query('userId') userId: string) {
    if (!userId) {
      throw new BadRequestException('userId query parameter is required');
    }
    return { count: this.syncService.getBlobCount(userId) };
  }
}
