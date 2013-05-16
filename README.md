# Prattle

The missing notifications for your GitHub pull requests.


## The problem

GitHub's commit status API is great for CI. Just push a branch to a pull
request and CI will run against it and tell you if it's safe to merge to
master. But once you push, you're waiting around for CI to finish. Wouldn't it
be nice if you were notified when the PR went red or green? You bet it would.

The easiest way to do that is to leave a comment saying that the PR has passed
or failed. That's exactly what Prattle does for you.


## Usage

- Create an application in GitHub.
- Push this repo to a new Heroku app.
- Visit the app in a browser.
- Follow the setup instructions.
- Log in with GitHub.
- Turn on any repos you want to track.

Now, any time the status of the latest commit on a PR changes, you'll get a
notification.


## License

Copyright (c) 2013 GoDaddy, LLC.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
