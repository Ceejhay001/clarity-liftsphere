import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new workout",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const workout = {
            name: "Full Body Workout",
            description: "Complete full body workout routine",
            exercises: ["Squat", "Bench Press", "Deadlift"]
        };

        let block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'create-workout', [
                types.ascii(workout.name),
                types.ascii(workout.description),
                types.list(workout.exercises.map(e => types.ascii(e)))
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk();
        assertEquals(block.receipts[0].result.expectOk(), types.uint(0));
    }
});

Clarinet.test({
    name: "Can log a workout",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'log-workout', [
                types.uint(0),
                types.list([types.uint(3), types.uint(3), types.uint(3)]),
                types.list([types.uint(10), types.uint(8), types.uint(6)]),
                types.list([types.uint(225), types.uint(185), types.uint(315)])
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Only owner can create achievements",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'create-achievement', [
                types.ascii("Iron Warrior"),
                types.ascii("Complete 100 workouts"),
                types.uint(100),
                types.ascii("workout-count")
            ], wallet1.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(100)); // err-owner-only
    }
});

Clarinet.test({
    name: "Can check achievement status",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'check-achievement', [
                types.principal(wallet1.address),
                types.uint(1)
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk();
    }
});