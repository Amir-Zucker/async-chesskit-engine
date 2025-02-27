//
//  arasan+engine.cpp
//
//  Created by Amir Zucker on 10/01/2025
//

#import "arasan+engine.h"

#include "../Arasan/src/types.h"
#include "../Arasan/src/globals.h"
#include "../Arasan/src/options.h"
#include "../Arasan/src/protocol.h"

#include <iostream>
#include <fstream>

Protocol *protocol;

void ArasanEngine::initialize() {
    signal(SIGINT,SIG_IGN);

    //print arasan data to console.
    std::cout << "Arasan " Arasan_Version << ' ' << Arasan_Copyright << std::endl;
    // Must use unbuffered console
    setbuf(stdin,NULL);
    setbuf(stdout, NULL);
    std::cout.rdbuf()->pubsetbuf(NULL, 0);
    std::cin.rdbuf()->pubsetbuf(NULL, 0);
    
    Bitboard::init();
    Board::init();
    globals::initOptions();
    Attacks::init();
    Scoring::init();
    Search::init();
    if (!globals::initGlobals()) {
        std::cerr << "failed to init arasan chess engine" << std::endl;
        deinitialize();
        return;
    }

    struct rlimit rl;
    const rlim_t STACK_MAX = static_cast<rlim_t>(globals::LINUX_STACK_SIZE);
    auto result = getrlimit(RLIMIT_STACK, &rl);
    if (result == 0)
    {
        if (rl.rlim_cur < STACK_MAX && rl.rlim_max >= STACK_MAX)
        {
            rl.rlim_cur = STACK_MAX;
            result = setrlimit(RLIMIT_STACK, &rl);
            if (result)
            {
                std::cerr << "failed to increase stack size" << std::endl;
                deinitialize();
                return;
            }
        }
    }

    bool ics = true, trace = false, cpusSet = false, memorySet = false;
    
    Board board;
    protocol = new Protocol(board, trace, ics, cpusSet, memorySet);
    // Begins protocol (UCI) run loop, listening on standard input
    // This loop continues until globals::polling_terminated is set to true. 
    protocol->poll(globals::polling_terminated);
    
    delete protocol;
}

void ArasanEngine::deinitialize() {
    globals::polling_terminated = true;
    globals::cleanupGlobals();
}
