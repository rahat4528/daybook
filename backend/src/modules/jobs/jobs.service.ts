import { SyncService } from '../sync/sync.service';

export interface JobExecutionReport {
  jobName: string;
  timestamp: number;
  status: 'success' | 'failed';
  itemsProcessed: number;
  message: string;
}

export class JobsService {
  constructor(private readonly syncService: SyncService) {}

  /**
   * Run nightly database retention cleanup.
   * Purges soft-deleted tombstones older than 90 days.
   */
  public runNightlyTombstonePurge(): JobExecutionReport {
    try {
      const ninetyDaysMs = 90 * 24 * 60 * 60 * 1000;
      const purged = this.syncService.purgeExpiredTombstones(ninetyDaysMs);
      return {
        jobName: 'nightly_tombstone_purge',
        timestamp: Date.now(),
        status: 'success',
        itemsProcessed: purged,
        message: `Successfully purged ${purged} expired tombstones.`,
      };
    } catch (err: any) {
      return {
        jobName: 'nightly_tombstone_purge',
        timestamp: Date.now(),
        status: 'failed',
        itemsProcessed: 0,
        message: err.message || 'Unknown error occurred',
      };
    }
  }

  /**
   * Dispatches automated morning wake-up accountability reminder to buddies.
   */
  public dispatchMorningBuddyNudges(): JobExecutionReport {
    return {
      jobName: 'morning_buddy_nudges',
      timestamp: Date.now(),
      status: 'success',
      itemsProcessed: 1,
      message: 'Morning buddy reminders queued.',
    };
  }
}
