import { Address, toNano } from '@ton/core';
import { JettonMaster } from '../wrappers/JettonMaster';
import { NetworkProvider } from '@ton/blueprint';
import { buildOnchainMetadata } from './utils/helpers';

export async function run(provider: NetworkProvider) {
    // const deployedContractAddress = Address.parse('EQBNBGAKYU6KdaQTq-IOTzcEppqWBktQRxG7EAlakwxMbHA5');
    const deployedContractAddress = Address.parse('EQDuKdpOpBhwYjDA-7wtNkrqp7CO-OBbofQyFUC35xLByBfV');
    // const receiverAddress = Address.parse('0QBNWh2vUbs2e2eFUBKhNQyoP33NHvo6r8ZIxfeP4RGQGJr2');
    const receiverAddress = Address.parse('0QC2E6gMfVrae_fvkymptz5V1JBERsWtgDLuLNqqmNfjB7EC');

    const jettonMaster = provider.open(await JettonMaster.fromAddress(deployedContractAddress));

    await jettonMaster.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Mint',
            amount: toNano(888),
            // receiver: provider.sender().address!!,
            receiver: receiverAddress,
        },
    );

    // await provider.waitForDeploy(counter.address);

    // run methods on `counter`
}
