import { Module, MiddlewareConsumer, RequestMethod } from '@nestjs/common';
import { AuthService } from './modules/auth/auth.service';
import { SyncService } from './modules/sync/sync.service';
import { LlmProxyService } from './modules/llm-proxy/llm-proxy.service';
import { BuddyService } from './modules/buddy/buddy.service';
import { JobsService } from './modules/jobs/jobs.service';

@Module({
  imports: [],
  controllers: [],
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
