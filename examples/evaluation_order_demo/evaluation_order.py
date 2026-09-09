obj = {}


def expr1():
    print("expr1")
    return obj


def expr2():
    print("expr2")
    return "answer"


def expr3():
    print("expr3")
    return 42


def expr4():
    print("expr4")
    return obj


def expr5():
    print("expr5")
    return "answer"


def expr6():
    print("expr6")
    return 1


def expr7(value1, value2, value3):
    print("expr7")


def expr8():
    print("expr8")
    return 8


def expr9():
    print("expr9")
    return 9


def expr10():
    print("expr10")
    return 10


print("Python: 'expr1()[expr2()] = expr3()'")
expr1()[expr2()] = expr3()
print(obj["answer"])

print("Python: 'expr4()[expr5()] += expr6()'")
expr4()[expr5()] += expr6()
print(obj["answer"])

print("Python: 'expr7(expr8(), expr9(), expr10())'")
expr7(expr8(), expr9(), expr10())
