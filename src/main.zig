const std = @import("std");
const Chan = @import("channel.zig");

//// **Rust Example**
// use std::sync::mpsc;
// use std::sync::{Arc, Mutex};
// use std::thread;
//
// pub fn main() {
//     // Create a channel to communicate between the main thread and the spawned threads
//     let (sender, receiver) = mpsc::channel();
//     let mut threads = vec![];
//
//     let receiver_arc = Arc::new(Mutex::new(receiver));
//
//     // Spawn two threads
//     for i in 0..2 {
//         let receiver_clone = Arc::clone(&receiver_arc); // Clone the receiver for each thread
//
//         let t = thread::spawn(move || {
//             // Receive message from the main thread
//             let msg = receiver_clone.lock().unwrap().recv().unwrap();
//             println!("Thread {} received message: {}", i + 1, msg);
//         });
//         threads.push(t);
//     }
//
//     // Send messages to the spawned threads
//     sender.send("Hello from main thread!").unwrap();
//
//     sender.send("Another message from main thread!").unwrap();
//
//     for th in threads {
//         th.join().unwrap();
//     }
// }

//// **Go Example**
// package main
//
// import (
// 	"fmt"
// 	"sync"
// )
//
// func main() {
// 	var wg sync.WaitGroup
// 	var ch = make(chan string, 2)
//
// 	// Add 2 to the WaitGroup counter
// 	wg.Add(2)
//
// 	// Launch two goroutines
// 	go func(ch chan string) {
// 		defer wg.Done() // Decrement the counter when the goroutine completes
// 		fmt.Println("Goroutine 1: ", <-ch)
// 	}(ch)
//
// 	// Launch two goroutines
// 	go func(ch chan string) {
// 		defer wg.Done() // Decrement the counter when the goroutine completes
// 		fmt.Println("Goroutine 2: ", <-ch)
// 	}(ch)
//
// 	ch <- "Hello from main thread!"
// 	ch <- "Another message from main thread!"
//
// 	// Wait for all goroutines to finish
// 	wg.Wait()
// }

//// **Zig Example**
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("Leaked");
    const allocator = gpa.allocator();

    const T = Chan.Channel([]const u8);
    const channel = try T.init(allocator);
    defer channel.deinit();

    const tx = channel.getTx();
    const rx = channel.getRx();

    var wg = std.Thread.WaitGroup{};

    wg.spawnManager(runRx, .{ T.Rx, rx });
    wg.spawnManager(runRx, .{ T.Rx, rx });

    try tx.send("Hello from main thread!");
    try tx.send("Another message from main thread!");

    wg.wait();
}

fn runRx(comptime TRx: type, rx: TRx) void {
    std.debug.print("Thread {} received message: {s}\n", .{ std.Thread.getCurrentId(), rx.recv() });
}
