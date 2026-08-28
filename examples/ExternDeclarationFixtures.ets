/** ArkTS fixtures used by the Cangjie declarations in examples_using_extern.cj. */

export function greeter(callback: (message: string) => void): void {
  if (typeof callback !== 'function') {
    throw new Error(`greeter expected a function, received ${typeof callback}`);
  }
  callback('hello from ArkTS');
}

export function printToConsole(message: string): void {
  console.info(`ExternDeclarationFixtures, printToConsole: ${message}`);
}

export function testMultiGenericT<T, M>(value: T, _metadata: M): T {
  return value;
}

export class FixturePerson {
  name: string;

  constructor(name: string) {
    this.name = name;
  }

  greet(): string {
    return `Hello, ${this.name}`;
  }
}

export function createPerson(name: string): FixturePerson {
  return new FixturePerson(name);
}

export class FixtureCalculator {
  add(x: number | string, y: number | string): number | string {
    if (typeof x === 'number' && typeof y === 'number') {
      return x + y;
    }
    return `${x}${y}`;
  }
}

export function createCalculator(): FixtureCalculator {
  return new FixtureCalculator();
}

export class FixtureStringList {
  items: string[];

  constructor(items: string[]) {
    this.items = items;
  }

  add(item: string): void {
    this.items.push(item);
  }
}

export function createStringList(items: string[]): FixtureStringList {
  return new FixtureStringList(items);
}

export class FixtureC {
  fCalls: number = 0;

  f(): void {
    this.fCalls += 1;
  }
}

export class FixtureF extends FixtureC {
  gCalls: number = 0;

  g(): void {
    this.gCalls += 1;
  }
}

export function createC(): FixtureC {
  return new FixtureC();
}

export function createD(): FixtureC {
  return new FixtureC();
}

export function createF(): FixtureF {
  return new FixtureF();
}

class FixtureGreeter {
  greeting: string;
  showCount: number = 0;

  constructor(greeting: string) {
    this.greeting = greeting;
  }

  showGreeting(): void {
    this.showCount += 1;
    console.info(this.greeting);
  }
}

// This is intentionally a factory function: Extern call syntax invokes the
// value directly and does not use ArkTS `new` syntax.
export function Greeter(greeting: string): FixtureGreeter {
  return new FixtureGreeter(greeting);
}

export class MathUtils {
  static PI: number = 3.141592653589793;

  static square(value: number): number {
    return value * value;
  }
}

export class FixtureAnimal {
  name: string;
  soundCount: number = 0;

  constructor(name: string) {
    this.name = name;
  }

  makeSound(): void {
    this.soundCount += 1;
  }
}

export function createAnimal(name: string): FixtureAnimal {
  return new FixtureAnimal(name);
}

export class FixtureBox<T> {
  value: T;

  constructor(value: T) {
    this.value = value;
  }

  getValue(): T {
    return this.value;
  }
}

export function createBox<T>(value: T): FixtureBox<T> {
  return new FixtureBox<T>(value);
}

export interface FixtureListener {
  onStart?: () => void;
  onDestroy?: () => void;
  onError?: (code: number, message: string) => void;
  onTouch?: () => void;
  onEvent?: (event: number) => void;
}

export function invokeListener(listener: FixtureListener): void {
  listener.onStart?.();
  listener.onDestroy?.();
  listener.onError?.(7, 'fixture error');
  listener.onTouch?.();
  listener.onEvent?.(0);
}

let arkListenerCalls: number = 0;

export function resetArkListenerCalls(): void {
  arkListenerCalls = 0;
}

export function createArkTSListener(): FixtureListener {
  return {
    onStart: (): void => { arkListenerCalls += 1; },
    onDestroy: (): void => { arkListenerCalls += 1; },
    onError: (_code: number, _message: string): void => { arkListenerCalls += 1; },
    onTouch: (): void => { arkListenerCalls += 1; },
    onEvent: (_event: number): void => { arkListenerCalls += 1; }
  };
}

export function getArkListenerCalls(): number {
  return arkListenerCalls;
}

export function ensureExternFixturesLinked(): void {}
