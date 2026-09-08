obj = {}

function expr1() {
  console.log("js expr1");
  return obj;
}

function expr2() {
  console.log("js expr2");
  return "answer";
}

function expr3() {
  console.log("js expr3");
  return 42;
}

function expr4() {
  console.log("js expr4");
  return obj;
}

function expr5() {
  console.log("js expr5");
  return "answer";
}

function expr6() {
  console.log("js expr6");
  return 1;
}

expr1()[expr2()] = expr3();
console.log(obj.answer);

expr4()[expr5()] += expr6();
console.log(obj.answer);
