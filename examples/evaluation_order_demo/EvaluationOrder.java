class EvaluationOrder {
    static final int[] obj = new int[1];

    static int[] expr1() {
        System.out.println("expr1");
        return obj;
    }

    static int expr2() {
        System.out.println("expr2");
        return 0;
    }

    static int expr3() {
        System.out.println("expr3");
        return 42;
    }

    static int[] expr4() {
        System.out.println("expr4");
        return obj;
    }

    static int expr5() {
        System.out.println("expr5");
        return 0;
    }

    static int expr6() {
        System.out.println("expr6");
        return 1;
    }

    static void expr7(int value1, int value2, int value3) {
        System.out.println("expr7");
    }

    static int expr8() {
        System.out.println("expr8");
        return 8;
    }

    static int expr9() {
        System.out.println("expr9");
        return 9;
    }

    static int expr10() {
        System.out.println("expr10");
        return 10;
    }

    public static void main(String[] args) {
        System.out.println("Java: 'expr1()[expr2()] = expr3()'");
        expr1()[expr2()] = expr3();
        System.out.println(obj[0]);

        System.out.println("Java: 'expr4()[expr5()] += expr6()'");
        expr4()[expr5()] += expr6();
        System.out.println(obj[0]);

        System.out.println("Java: 'expr7(expr8(), expr9(), expr10())'");
        expr7(expr8(), expr9(), expr10());
    }
}
