import abilityTest from './Ability.test';
import xmlReaderDecodingTest from './XmlReader.test';

export default function testsuite() {
  abilityTest();
  xmlReaderDecodingTest();
}