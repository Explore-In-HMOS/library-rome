// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Scene.java (Apache-2.0)
import { Time } from './Time';

export class Scene {
  title: string | null = null;
  description: string | null = null;
  startTime: Time | null = null;
  endTime: Time | null = null;
}
