pragma circom  2.0.0;

template identityVerification() {

    signal input expectedHash; //stored on-chain
    signal input userHash; //provided by user

    signal output isValidHash;
    userHash === expectedHash;

    isValidHash <== userHash;
}

component main = identityVerification();
