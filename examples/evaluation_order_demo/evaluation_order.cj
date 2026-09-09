let obj: Array<Int64> = [0]

func expr1(): Array<Int64> {
    println("expr1")
    return obj
}

func expr2(): Int64 {
    println("expr2")
    return 0
}

func expr3(): Int64 {
    println("expr3")
    return 42
}

func expr4(): Array<Int64> {
    println("expr4")
    return obj
}

func expr5(): Int64 {
    println("expr5")
    return 0
}

func expr6(): Int64 {
    println("expr6")
    return 1
}

func expr7(_: Int64, _: Int64, _: Int64): Unit {
    println("expr7")
}

func expr8(): Int64 {
    println("expr8")
    return 8
}

func expr9(): Int64 {
    println("expr9")
    return 9
}

func expr10(): Int64 {
    println("expr10")
    return 10
}

main(): Int64 {
    println("Cangjie: 'expr1()[expr2()] = expr3()'")
    expr1()[expr2()] = expr3()
    println(obj[0])

    println("Cangjie: 'expr4()[expr5()] += expr6()'")
    expr4()[expr5()] += expr6()
    println(obj[0])

    println("Cangjie: 'expr7(expr8(), expr9(), expr10())'")
    expr7(expr8(), expr9(), expr10())
    return 0
}
