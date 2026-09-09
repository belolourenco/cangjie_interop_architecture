obj = {}

function expr1() {
  console.log("expr1");
  return obj;
}

function expr2() {
  console.log("expr2");
  return "answer";
}

function expr3() {
  console.log("expr3");
  return 42;
}

function expr4() {
  console.log("expr4");
  return obj;
}

function expr5() {
  console.log("expr5");
  return "answer";
}

function expr6() {
  console.log("expr6");
  return 1;
}

function expr7(value1, value2, value3) {
  console.log("expr7");
}

function expr8() {
  console.log("expr8");
  return 8;
}

function expr9() {
  console.log("expr9");
  return 9;
}

function expr10() {
  console.log("expr10");
  return 10;
}

console.log("JavaScript: 'expr1()[expr2()] = expr3()'");
expr1()[expr2()] = expr3();
console.log(obj.answer);

console.log("JavaScript: 'expr4()[expr5()] += expr6()'");
expr4()[expr5()] += expr6();
console.log(obj.answer);

console.log("JavaScript: 'expr7(expr8(), expr9(), expr10())'");
expr7(expr8(), expr9(), expr10());
