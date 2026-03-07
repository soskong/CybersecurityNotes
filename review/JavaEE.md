#### Spring MVC

Spring MVC工作原理

SpringMVC三大组件，处理器映射器（HandlerMapping），处理器适配器（HandlerAdapter），视图解析器（ViewResolver）

1. 用户向浏览器发送请求，请求被SpringMVC的前端控制器（DispatcherSevlet）拦截
2. DispatcherSevlet拦截后会调用处理器映射器（HandlerMapping）
3. 处理器映射器跟据请求的URL找到具体的处理器，生成处理器对象及处理器拦截器（如有则生成），返回给DispatcherSevlet
4. DispatcherSevlet跟据返回的信息选择合适的处理器适配器（HandlerAdapter）
5. HandlerAdapter调用并执行处理器（Handler），处理器指的是Controller类，也称为后端控制器
6. Controller执行完后会返回一个ModelAndView对象
7. HandlerAdapter将ModelAndView对象返回给DispatcherSevlet
8. 前端控制器请求视图解析器解析
