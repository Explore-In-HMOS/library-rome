// Ported from ROME rome-modules/src/main/java/com/rometools/modules/cc/types/License.java (Apache-2.0)
import { JavaConcurrentHashMap } from '../../../utils/JavaConcurrentHashMap';

// License.Behaviour; toString() is the URI.
export enum LicenseBehaviour {
  REPRODUCTION = 'http://web.resource.org/cc/Reproduction',
  DISTRIBUTION = 'http://web.resource.org/cc/Distribution',
  DERIVATIVE = 'http://web.resource.org/cc/DerivativeWorks',
  NOTICE = 'http://web.resource.org/cc/Notice',
  ATTRIBUTION = 'http://web.resource.org/cc/Attribution',
  COPYLEFT = 'http://web.resource.org/cc/Copyleft',
  NONCOMMERCIAL = 'http://web.resource.org/cc/Noncommercial'
}

const BEHAVIOURS: LicenseBehaviour[] = [LicenseBehaviour.REPRODUCTION, LicenseBehaviour.DISTRIBUTION,
  LicenseBehaviour.DERIVATIVE, LicenseBehaviour.NOTICE, LicenseBehaviour.ATTRIBUTION, LicenseBehaviour.COPYLEFT,
  LicenseBehaviour.NONCOMMERCIAL];

// License.Behaviour.findByValue.
export function findBehaviourByValue(uri: string | null): LicenseBehaviour | null {
  return BEHAVIOURS.find((b: LicenseBehaviour) => b === uri) ?? null;
}

const CC_START: string = 'http://creativecommons.org/licenses/';
const lookupLicense: JavaConcurrentHashMap<License> = new JavaConcurrentHashMap<License>();

type Behaviours = (LicenseBehaviour | null)[] | null;

export class License {
  readonly value: string;
  readonly permits: Behaviours;
  readonly requires: Behaviours;

  constructor(uri: string, requires: Behaviours, permits: Behaviours) {
    this.requires = requires;
    this.permits = permits;
    this.value = uri;
    lookupLicense.put(uri, this);
    if (uri.endsWith('/')) {
      lookupLicense.put(uri.substring(0, uri.lastIndexOf('/')), this);
    }
  }

  static readonly NO_DERIVS: License = new License('http://creativecommons.org/licenses/nd/1.0/', [],
    [LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly NO_DERIVS_NONCOMMERCIAL: License = new License('http://creativecommons.org/licenses/nd-nc/1.0/',
    [LicenseBehaviour.NONCOMMERCIAL], [LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly NONCOMMERCIAL: License = new License('http://creativecommons.org/licenses/nc/1.0/',
    [LicenseBehaviour.NONCOMMERCIAL],
    [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly SHARE_ALIKE: License = new License('http://creativecommons.org/licenses/sa/1.0/',
    [LicenseBehaviour.COPYLEFT], [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly SHARE_ALIKE_NONCOMMERCIAL: License = new License('http://creativecommons.org/licenses/nc-sa/1.0/',
    [LicenseBehaviour.COPYLEFT, LicenseBehaviour.NONCOMMERCIAL],
    [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly SHARE_ALIKE_ATTRIBUTION: License = new License('http://creativecommons.org/licenses/by-sa/2.5/',
    [LicenseBehaviour.COPYLEFT, LicenseBehaviour.ATTRIBUTION],
    [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly SHARE_ALIKE_NONCOMMERCIAL_ATTRIBUTION: License = new License(
    'http://creativecommons.org/licenses/by-nc-sa/2.5/',
    [LicenseBehaviour.COPYLEFT, LicenseBehaviour.ATTRIBUTION, LicenseBehaviour.NONCOMMERCIAL],
    [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly NONCOMMERCIAL_ATTRIBUTION: License = new License('http://creativecommons.org/licenses/by-nc/2.5/',
    [LicenseBehaviour.ATTRIBUTION, LicenseBehaviour.NONCOMMERCIAL],
    [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly NONCOMMERCIAL_ATTRIBUTION_NO_DERIVS: License = new License(
    'http://creativecommons.org/licenses/by-nc-nd/2.5/', [LicenseBehaviour.ATTRIBUTION, LicenseBehaviour.NONCOMMERCIAL],
    [LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly ATTRIBUTION_NO_DERIVS: License = new License('http://creativecommons.org/licenses/by-nd/2.5/',
    [LicenseBehaviour.ATTRIBUTION], [LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);
  static readonly ATTRIBUTION: License = new License('http://creativecommons.org/licenses/by/2.5/',
    [LicenseBehaviour.ATTRIBUTION],
    [LicenseBehaviour.DERIVATIVE, LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION]);

  // An unknown creativecommons.org URI takes the behaviours of the first registered license whose first path segment
  // it contains, in the registry's iteration order; every license created is registered, so results depend on history.
  static findByValue(uri: string): License {
    let found = lookupLicense.get(uri) ?? null;
    if (found === null && uri.startsWith('http://') && uri.toLowerCase().indexOf('creativecommons.org') !== -1) {
      for (const key of lookupLicense.keys()) {
        if (!key.startsWith(CC_START)) {
          continue;
        }
        const license = key.substring(CC_START.length).split('/').find((t: string) => t.length > 0);
        if (license !== undefined && uri.toLowerCase().indexOf('creativecommons.org/licenses/' + license) !== -1) {
          const current = lookupLicense.get(key)!;
          found = new License(uri, current.requires, current.permits);
          break;
        }
      }
    }
    return found ?? new License(uri, null, null);
  }

  static clear(): void {
    lookupLicense.clear();
  }
}
