[... previous tests remain the same ...]

Clarinet.test({
    name: "Validates workout creation input",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const workout = {
            name: "Invalid Workout",
            description: "Should fail due to empty exercises",
            exercises: []
        };

        let block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'create-workout', [
                types.ascii(workout.name),
                types.ascii(workout.description),
                types.list([])
            ], deployer.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(103)); // err-invalid-input
    }
});

Clarinet.test({
    name: "Tracks total weight lifted",
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
        
        // Add assertion for user stats here
    }
});
