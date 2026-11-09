// Ported from ROME rome/src/main/java/com/rometools/rome/feed/module/{SyModule,SyModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from './Module';
import { IllegalArgumentException } from '../../utils/Exceptions';

const PERIODS: string[] = ['hourly', 'daily', 'weekly', 'monthly', 'yearly'];

export class SyModule extends ModuleImpl {
  static readonly URI: string = 'http://purl.org/rss/1.0/modules/syndication/';
  static readonly HOURLY: string = 'hourly';
  static readonly DAILY: string = 'daily';
  static readonly WEEKLY: string = 'weekly';
  static readonly MONTHLY: string = 'monthly';
  static readonly YEARLY: string = 'yearly';

  private _updatePeriod: string | null = null;
  updateFrequency: number = 0;
  updateBase: Date | null = null;

  constructor() {
    super(SyModule.URI);
  }

  get updatePeriod(): string | null {
    return this._updatePeriod;
  }

  set updatePeriod(updatePeriod: string | null) {
    if (updatePeriod === null || !PERIODS.includes(updatePeriod)) {
      throw new IllegalArgumentException('Invalid period [' + updatePeriod + ']');
    }
    this._updatePeriod = updatePeriod;
  }

  clone(): SyModule {
    const copy = new SyModule();
    copy.copyFrom(this);
    return copy;
  }

  // CopyFromHelper skips properties that are null in the source.
  copyFrom(obj: Module): void {
    const sy = obj as SyModule;
    if (sy._updatePeriod !== null) {
      this._updatePeriod = sy._updatePeriod;
    }
    this.updateFrequency = sy.updateFrequency;
    if (sy.updateBase !== null) {
      this.updateBase = new Date(sy.updateBase.getTime());
    }
  }
}
