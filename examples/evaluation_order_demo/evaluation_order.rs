use std::sync::{Mutex, MutexGuard};

static OBJ: Mutex<[i32; 1]> = Mutex::new([0]);

fn expr1() -> MutexGuard<'static, [i32; 1]> {
    println!("expr1");
    OBJ.lock().unwrap()
}

fn expr2() -> usize {
    println!("expr2");
    0
}

fn expr3() -> i32 {
    println!("expr3");
    42
}

fn expr4() -> MutexGuard<'static, [i32; 1]> {
    println!("expr4");
    OBJ.lock().unwrap()
}

fn expr5() -> usize {
    println!("expr5");
    0
}

fn expr6() -> i32 {
    println!("expr6");
    1
}

fn expr7(_: i32, _: i32, _: i32) {
    println!("expr7");
}

fn expr8() -> i32 {
    println!("expr8");
    8
}

fn expr9() -> i32 {
    println!("expr9");
    9
}

fn expr10() -> i32 {
    println!("expr10");
    10
}

fn main() {
    println!("Rust: 'expr1()[expr2()] = expr3()'");
    expr1()[expr2()] = expr3();
    println!("{}", OBJ.lock().unwrap()[0]);

    println!("Rust: 'expr4()[expr5()] += expr6()'");
    expr4()[expr5()] += expr6();
    println!("{}", OBJ.lock().unwrap()[0]);

    println!("Rust: 'expr7(expr8(), expr9(), expr10())'");
    expr7(expr8(), expr9(), expr10());
}
