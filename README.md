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

Push this repo to a new Heroku app. Then open app in a browser and follow the
instructions.

The app will instruct you to:

- Create an application in GitHub.
- Enter your Client ID and Client Secret.
- Authorize with GitHub.
- Turn on any repos you want to track.

Now, any time the status of the latest commit on a PR changes, you'll get a
notification.


FIXME: We're probably going to end up depending on Redis or another data
store, so be sure to add that to the Heroku instructions.

UNKNOWN: Can we get all of the repos this user is authed for?
