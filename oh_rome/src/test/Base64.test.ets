import { describe, expect, it } from '@ohos/hypium';
import { Base64 } from '../main/ets/io/impl/Base64';

function testEncodeDecode(s: string): void {
  expect(Base64.decode(Base64.encode(s))).assertEqual(s);
}


function thrown(action: () => void): string {
  try {
    action();
  } catch (e) {
    const error = e as Error;
    return error.name === 'Error' ? error.message : `${error.name}: ${error.message}`;
  }
  return 'nothing thrown';
}

export default function base64Test() {
  describe('Base64', () => {
    // rome/src/test/java/com/rometools/rome/unittest/TestBase64.java
    it('testEncodeDecode', 0, () => {
      testEncodeDecode('');
      testEncodeDecode('A');
      testEncodeDecode('AB');
      testEncodeDecode('ABC');
      testEncodeDecode('ABCD');
      testEncodeDecode('ABCDE');
      testEncodeDecode('&');
      testEncodeDecode('a&');
      testEncodeDecode('ab&');
      testEncodeDecode('abc&');
      testEncodeDecode('abcd&');
    });

    it('testDecodeWithEnters', 0, () => {
      const s = 'Hello World!';
      let encoded = Base64.encode(s);
      encoded = encoded.substring(0, 3) + '\n\r\n' + encoded.substring(3);
      expect(Base64.decode(encoded)).assertEqual(s);
    });

    // Results of ROME's Base64 on Temurin 17.0.17+10.
    // new String(bytes, UTF_8) on Temurin 17.0.17+10 collapses some malformed sequences into one U+FFFD.
    it('decodesMalformedUtf8LikeJdk17', 0, () => {
      expect(Base64.decode('7a10')).assertEqual('\ufffdt');
      expect(Base64.decode('7aCA')).assertEqual('\ufffd');
      expect(Base64.decode('7b+/gA==')).assertEqual('\ufffd\ufffd');
      expect(Base64.decode('8O2g8ICgkA==')).assertEqual('\ufffd\ufffd\ufffd\ufffd\ufffd\ufffd');
      expect(Base64.decode('7aDagJD0kJA=')).assertEqual('\ufffd\u0680\ufffd\ufffd\ufffd\ufffd');
      expect(Base64.decode('4KCgkOa24K/tpA==')).assertEqual('\u0820\ufffd\ufffd\ufffd\ufffd');
    });

    it('matchesRomeOutput', 0, () => {
      expect(Base64.encode('Hello World!')).assertEqual('SGVsbG8gV29ybGQh');
      expect(Base64.encode('héllo 😀 \ud800x')).assertEqual('aMOpbGxvIPCfmIAgP3g=');
      expect(Base64.decode('aMOpbGxvIPCfmIAgPw==')).assertEqual('héllo 😀 ?');
      expect(Base64.decode('/w==')).assertEqual('�');
      expect(Base64.decode('QUJD RA=')).assertEqual('ABCD');
      expect(thrown(() => Base64.decode('QQ==QQ=='))).assertEqual('Index 3 out of bounds for length 3');
      expect(thrown(() => Base64.decode('QUJDRA='))).assertEqual('Index 7 out of bounds for length 7');
      expect(thrown(() => Base64.decode('QUJ'))).assertEqual('Index 3 out of bounds for length 3');
      expect(thrown(() => Base64.decode('é'))).assertEqual('Index -61 out of bounds for length 256');
      expect(thrown(() => Base64.decode('QUJDR')))
        .assertEqual('IllegalArgumentException: byte array is not a valid com.rometools.rome.io.impl.Base64 encoding');
    });
  });
}
