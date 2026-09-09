let obj: Array<Int64> = [0]

func expr1(): Array<Int64> {
    println("cangjie expr1")
    return obj
}

func expr2(): Int64 {
    println("cangjie expr2")
    return 0
}

func expr3(): Int64 {
    println("cangjie expr3")
    return 42
}

func expr4(): Array<Int64> {
    println("cangjie expr4")
    return obj
}

func expr5(): Int64 {
    println("cangjie expr5")
    return 0
}

func expr6(): Int64 {
    println("cangjie expr6")
    return 1
}

main(): Int64 {
    expr1()[expr2()] = expr3()
    println(obj[0])

    expr4()[expr5()] += expr6()
    println(obj[0])
    return 0
}
