import { Module } from '@nestjs/common';
import { AuthService } from './modules/auth/auth.service';
import { AuthController } from './modules/auth/auth.controller';
import { SyncService } from './modules/sync/sync.service';
import { SyncController } from './modules/sync/sync.controller';
import { LlmProxyService } from './modules/llm-proxy/llm-proxy.service';
import { LlmProxyController } from './modules/llm-proxy/llm-proxy.controller';
import { BuddyService } from './modules/buddy/buddy.service';
import { BuddyController } from './modules/buddy/buddy.controller';
import { JobsService } from './modules/jobs/jobs.service';
import { HealthController } from './modules/health/health.controller';

@Module({
  imports: [],
  controllers: [
    AuthController,
    SyncController,
    BuddyController,
    LlmProxyController,
    HealthController,
  ],
  providers: [
    AuthService,
    SyncService,
    LlmProxyService,
    BuddyService,
    {
      provide: JobsService,
      useFactory: (syncService: SyncService) => new JobsService(syncService),
      inject: [SyncService],
    },
  ],
  exports: [
    AuthService,
    SyncService,
    LlmProxyService,
    BuddyService,
    JobsService,
  ],
})
export class AppModule {}
