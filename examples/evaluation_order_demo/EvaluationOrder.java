class EvaluationOrder {
    static final int[] obj = new int[1];

    static int[] expr1() {
        System.out.println("java expr1");
        return obj;
    }

    static int expr2() {
        System.out.println("java expr2");
        return 0;
    }

    static int expr3() {
        System.out.println("java expr3");
        return 42;
    }

    static int[] expr4() {
        System.out.println("java expr4");
        return obj;
    }

    static int expr5() {
        System.out.println("java expr5");
        return 0;
    }

    static int expr6() {
        System.out.println("java expr6");
        return 1;
    }

    public static void main(String[] args) {
        expr1()[expr2()] = expr3();
        System.out.println(obj[0]);

        expr4()[expr5()] += expr6();
        System.out.println(obj[0]);
    }
}
