# RequestExceptionHandler

Rails is not capable of calling your exception handlers when an error occurs
during the parsing of request parameters (e.g. in case of invalid JSON body).

This will hopefully change someday, but until then I have created this delicate
monkey-patch for the request parameter parser to allow more flexibility when
an invalid request body is received.

Version 0.6.0 drop support for XML and Rails 3 and 2

Tested on 5.x and 4.x.
Please use gem 0.5.0 for compatibility with Rails 3.X and 2.x.

[![Build Status][0]](http://travis-ci.org/#!/kares/request_exception_handler)

## Install

    gem 'request_exception_handler'

## Example

The code hooks into parameter parsing and allows a request to be constructed
even if the parsing of the submitted raw content fails (JSON backend raises
a parse error). A before filter is installed that checks for a request exception
and re-raises, it thus it seems to Rails that the exception comes from the
application code and is processed as all other "business" exceptions.

One might skip this "request-exception" filter (e.g. per action - the usual way)
and install another to handle such cases (it's good to make sure the filter gets
at the beginning of the chain) :

```ruby
class MyController < ApplicationController

  skip_before_action :check_request_exception # filter the plugin installed

  # custom before action use request_exception to detect occured errors
  prepend_before_action :return_409_on_json_errors

  private
  def return_409_on_json_errors
    if e = request_exception && e.is_a?(ActiveSupport::JSON::ParseError)
      head 409
    else
      head 500
    end
  end

end
```

## Copyright

Copyright (c) 2014 [Karol Bucek](https://github.com/kares).
Copyright (c) 2019 [Thomas Lecavelier](https://github.com/ook).
See LICENSE (http://www.apache.org/licenses/LICENSE-2.0) for details.

[0]: https://secure.travis-ci.org/kares/request_exception_handler.png
