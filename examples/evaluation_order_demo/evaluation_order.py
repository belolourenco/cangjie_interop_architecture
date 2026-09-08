obj = {}


def expr1():
    print("py expr1")
    return obj


def expr2():
    print("py expr2")
    return "answer"


def expr3():
    print("py expr3")
    return 42


def expr4():
    print("py expr4")
    return obj


def expr5():
    print("py expr5")
    return "answer"


def expr6():
    print("py expr6")
    return 1


expr1()[expr2()] = expr3()
print(obj["answer"])

expr4()[expr5()] += expr6()
print(obj["answer"])
