--!strict

local PromiseApi: any = require(script.PromiseApi)

export type ClassType = Promise
export type Status = ("Started" | "Resolved" | "Rejected" | "Cancelled")

type fn<args..., ret...> = (args...) -> (ret...)
type anyFn = fn<...any, ...any>
type anyArgs = fn<...any>
type anyRet<ret...> = fn<...any, ret...>

type Promise = {
	andThen: (self: Promise, successHandler: anyFn, failureHandler: anyFn?) -> Promise,
	andThenCall: (self: Promise, callback: anyFn, ...any) -> Promise,
	andThenReturn: (self: Promise, ...any) -> Promise,
	await: (self: Promise) -> (boolean, ...any),
	awaitStatus: (self: Promise) -> (Status, ...any),
	cancel: (self: Promise) -> (),
	catch: (self: Promise, failureHandler: anyFn) -> Promise,
	expect: (self: Promise) -> ...any,
	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	finallyCall: (self: Promise, anyFn) -> Promise,
	finallyReturn: (self: Promise, ...any) -> Promise,
	getStatus: (self: Promise) -> Status,
	now: (self: Promise, rejectionValue: any?) -> Promise,
	tap: (self: Promise, tapHandler: anyFn) -> Promise,
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

return PromiseApi :: {
	Status: {
		Started: "Started",
		Resolved: "Resolved",
		Rejected: "Rejected",
		Cancelled: "Cancelled",
	},

	new: (executor: (resolve: anyArgs, reject: anyArgs, onCancel: (abortHandler: () -> ()?) -> boolean) -> ()) -> Promise,
	defer: (executor: (resolve: anyArgs, reject: anyArgs, onCancel: (abortHandler: () -> ()?) -> boolean) -> ()) -> Promise,

	resolve: anyRet<Promise>,
	reject: anyRet<Promise>,

	try: (callback: anyFn, ...any) -> Promise,
	all: (promises: { Promise }) -> Promise,

	fold: (list: { any | Promise }, reducer: (accumulator: any, value: any, index: number) -> (any | Promise), initialValue: any) -> (),

	some: (promises: { Promise }, count: number) -> Promise,
	any: (promises: { Promise }) -> Promise,
	allSettled: (promises: { Promise }) -> Promise,
	race: (promises: { Promise }) -> Promise,
	each: (list: { any | Promise }, predicate: (any, any) -> any | Promise) -> Promise,
	is: (object: any) -> boolean,
	promisify: (callback: anyFn) -> anyRet<Promise>,
	retry: (callback: (...any) -> Promise, times: number, ...any) -> Promise,
	retryWithDelay: (callback: anyRet<Promise>, times: number, seconds: number, ...any) -> Promise,
	fromEvent: (event: { Connect: anyFn }, predicate: anyRet<boolean>) -> Promise,
	onUnhandledRejection: (callback: (promise: Promise, ...any) -> ()) -> () -> (),
}
