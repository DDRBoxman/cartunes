//
//  CarThingProtocol.swift
//  cartunes
//
//  Created by Colin Edwards on 5/21/23.
//

import Foundation


enum CarThingMessage: Int8 {
    case HELLO = 1
    case WELCOME = 2
    case ABORT = 3
    case CHALLENGE = 4
    case AUTHENTICATE = 5
    case GOODBYE = 6
    case ERROR = 8
    case PUBLISH = 16
    case PUBLISHED = 17
    case SUBSCRIBE = 32
    case SUBSCRIBED = 33
    case UNSUBSCRIBE = 34
    case UNSUBSCRIBED = 35
    case EVENT = 36
    case CALL = 48
    case CANCEL = 49
    case RESULT = 50
    case REGISTER = 64
    case REGISTERED = 65
    case UNREGISTER = 66
    case UNREGISTERED = 67
    case INVOCATION = 68
    case INTERRUPT = 69
    case YIELD = 70
}
