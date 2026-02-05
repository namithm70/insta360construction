package com.arashivision.sdk.lib;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Test {

    private static final ExecutorService executor = Executors.newFixedThreadPool(3);

    public static void main(String[] args) {
        // 任务1：获取用户ID
        CompletableFuture<String> userIdFuture = CompletableFuture.supplyAsync(() -> {
            // 模拟获取用户ID的操作
            return "user123";
        }, executor);

        // 任务2：根据用户ID获取订单信息
        CompletableFuture<String> orderFuture = userIdFuture.thenApplyAsync(userId -> {
            // 模拟获取订单信息的操作
            return "order456 for " + userId;
        }, executor);

        // 任务3：根据订单信息获取支付详情
        CompletableFuture<String> paymentFuture = orderFuture.thenApplyAsync(order -> {
            // 模拟获取支付详情的操作
            return "payment details for " + order;
        }, executor);

        // 任务4：处理结果
        paymentFuture.thenAcceptAsync(result -> {
            System.out.println("Final result: " + result);
        }, executor).exceptionally(ex -> {
            ex.printStackTrace();
            return null;
        });

        // 主线程继续执行其他任务
        System.out.println("Main thread continues...");

        // 关闭线程池
        executor.shutdown();
    }
}
