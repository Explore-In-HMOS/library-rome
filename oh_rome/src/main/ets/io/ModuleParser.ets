// Ported from ROME rome/src/main/java/com/rometools/rome/io/ModuleParser.java (Apache-2.0)
import { Element } from '../xml/Dom';
import { Module } from '../feed/module/Module';

export interface ModuleParser {
  getNamespaceUri(): string;

  parse(element: Element): Module | null;
}
