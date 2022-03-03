"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[273],{25304:function(e,n,a){a.r(n),a.d(n,{frontMatter:function(){return l},contentTitle:function(){return s},metadata:function(){return c},toc:function(){return p},default:function(){return m}});var t=a(87462),i=a(63366),o=(a(67294),a(3905)),r=["components"],l={title:"Examples"},s="Examples",c={unversionedId:"Examples",id:"Examples",isDocsHomePage:!1,title:"Examples",description:"Chaining",source:"@site/docs/Examples.md",sourceDirName:".",slug:"/Examples",permalink:"/roblox-lua-promise/docs/Examples",editUrl:"https://github.com/evaera/roblox-lua-promise/edit/master/docs/Examples.md",tags:[],version:"current",frontMatter:{title:"Examples"},sidebar:"defaultSidebar",previous:{title:"Why use Promises?",permalink:"/roblox-lua-promise/docs/WhyUsePromises"}},p=[{value:"Chaining",id:"chaining",children:[],level:2},{value:"IsInGroup wrapper",id:"isingroup-wrapper",children:[],level:2},{value:"TweenService wrapper",id:"tweenservice-wrapper",children:[],level:2},{value:"Cancellable animation sequence",id:"cancellable-animation-sequence",children:[],level:2}],u={toc:p};function m(e){var n=e.components,a=(0,i.Z)(e,r);return(0,o.kt)("wrapper",(0,t.Z)({},u,a,{components:n,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"examples"},"Examples"),(0,o.kt)("h2",{id:"chaining"},"Chaining"),(0,o.kt)("p",null,"Chain together multiple Promise-returning functions, and only handle a potential error once. If any function rejects in the chain, execution will jump down to ",(0,o.kt)("inlineCode",{parentName:"p"},"catch"),"."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-lua"},"    doSomething()\n        :andThen(doSomethingElse)\n        :andThen(doSomethingOtherThanThat)\n        :andThen(doSomethingAgain)\n        :catch(print)\n")),(0,o.kt)("h2",{id:"isingroup-wrapper"},"IsInGroup wrapper"),(0,o.kt)("p",null,"This function demonstrates how to convert a function that yields into a function that returns a Promise. (Assuming you don't want to use ",(0,o.kt)("a",{parentName:"p",href:"/api/Promise#promisify"},"Promise.promisify"),")"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-lua"},"local function isPlayerInGroup(player, groupId)\n    return Promise.new(function(resolve)\n        resolve(player:IsInGroup(groupId))\n    end)\nend\n")),(0,o.kt)("h2",{id:"tweenservice-wrapper"},"TweenService wrapper"),(0,o.kt)("p",null,"This function demonstrates convert a Roblox API that uses events into a function that returns a Promise."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-lua"},"local function tween(obj, tweenInfo, props)\n    return function()\n        return Promise.new(function(resolve, reject, onCancel)\n            local tween = TweenService:Create(obj, tweenInfo, props)\n            \n            if onCancel(function()\n                tween:Cancel()\n            end) then return end\n            \n            tween.Completed:Connect(resolve)\n            tween:Play()\n        end)\n    end\nend\n")),(0,o.kt)("h2",{id:"cancellable-animation-sequence"},"Cancellable animation sequence"),(0,o.kt)("p",null,"The following is an example of an animation sequence which is composable and cancellable. If the sequence is cancelled, the animated part will instantly jump to the end position as if it had played all the way through."),(0,o.kt)("p",null,"We take advantage of Promise chaining by returning Promises from the ",(0,o.kt)("inlineCode",{parentName:"p"},"finally")," handler functions. Because of this behavior, cancelling the final Promise in the chain will propagate up to the very top and cancel every single Promise you see here."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-lua"},'local Promise = require(game.ReplicatedStorage.Promise)\nlocal TweenService = game:GetService("TweenService")\n\nlocal sleep = Promise.promisify(wait)\n\nlocal function apply(obj, props)\n    for key, value in pairs(props) do\n        obj[key] = value\n    end\nend\n\nlocal function runTween(obj, props)\n    return Promise.new(function(resolve, reject, onCancel)\n        local tween = TweenService:Create(obj, TweenInfo.new(0.5), props)\n        \n        if onCancel(function()\n            tween:Cancel()\n            apply(obj, props)\n        end) then return end\n        \n        tween.Completed:Connect(resolve)\n        tween:Play()\n    end)\nend\n\nlocal function runAnimation(part, intensity)\n    return Promise.resolve()\n        :finallyCall(sleep, 1)\n        :finallyCall(runTween, part, {\n            Reflectance = 1 * intensity\n        }):finallyCall(runTween, part, {\n            CFrame = CFrame.new(part.Position) *\n                CFrame.Angles(0, math.rad(90 * intensity), 0)\n        }):finallyCall(runTween, part, {\n            Size = (\n                Vector3.new(10, 10, 10) * intensity\n            ) + Vector3.new(1, 1, 1)\n        })\nend\n\nlocal animation = Promise.resolve() -- Begin Promise chain\n    :finallyCall(runAnimation, workspace.Part, 1)\n    :finallyCall(sleep, 1)\n    :finallyCall(runAnimation, workspace.Part, 0)\n    :catch(warn)\n\nwait(2)\nanimation:cancel() -- Remove this line to see the full animation\n')))}m.isMDXComponent=!0}}]);