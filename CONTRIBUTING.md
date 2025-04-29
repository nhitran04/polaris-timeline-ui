# Contributing

## Project Organization

Any questions should be directed to the admin of the project, David Porfirio (david.j.porfirio2.ctr@us.navy.mil).

## Setup Instructions for Newcomers

Welcome to the club! If you are new to Polaris, the first thing you'll need to do is checkout the `dev` branch.

```
git checkout dev
git branch 
```

The output of the above commands should tell you that you're on the `dev` branch.

Next, you need to create your own _working branch_.

```
git branch <yourfirstname>_dev
```

For example, David's working branch is `david_dev`. 

## Rules

Once you've setup your own branch, running `git branch` should output 3 branches (their order may differ):

```
* <yourfirstname>_dev
master
dev
```

Contributions to Polaris abide by the following rules:

1. `master` rule: NEVER push to or merge with `master` unless you are an admin of the project. The `master` branch should NOT be treated as a development branch under any circumstances whatsoever. `master` will only be updated when a new version of Polaris has been tested and is ready to ship.
2. `dev` rule: DO NOT push to or merge with `dev` unless given permission by an admin. The `dev` branch should NOT be treated as a development branch under any circumstances whatsoever. `dev` will only be updated when major changes are made to the code, but do not warrant a new version. 
3. `<yourfirstname>_branch`: You may push to this branch, with the following caveats:
	- *Every* commit should do _one_ thing and _one_ thing only
	- *No* commit to should introduce any bugs, i.e., break any test cases. If you're unsure whether a commit will introduce a bug, _write a test case._

Now you may be wondering, _"What if I want to save local progress even if it is unfinished? What if I want to be able to save my sloppy, in-progress code to the remote repo?"_ Great questions! You can *_absolutely_* save work in progress to your branch! But by the time it's ready to merge with `dev`, *_your branch should be clean and adhering to the rules above_*.

And now you may be asking, _"How do I clean up my in-progress code?"_ Another great question! The answer: get familiar with `git rebase`. It doesn't matter how you clean up your work in progress - the bottom line is that when it's ready to merge, it needs to adhere to the rules above.

Optional: feel free to create any additional branches from `<yourfirstname>_branch` that you can use to save your work in progress! For instance, you can feel free to create a `<yourfirstname>_wip` branch and save all of your work-in-progress (wip) work there. When you've cleaned up your work in progress, you can merge it with your own dev branch.

## Merging your Branch with `dev`

Create a pull request to merge `<yourfirstname>_dev` with `dev`.

- Write a concise title and give a few sentences description.
- Assign the assignee and reviewer to @dporfirio.
- Uncheck 'Delete source branch when merge request is accepted.' At the moment, branches do not represent new features, and are intended to be a developer's persistent working branch.
- Leave 'squash commits' unchecked.

Merge requests will either be approved or rejected.

## Keeping Track of `dev`

Whenever updates are made to `dev` (e.g., by another contributor), you will need to you pull dev onto your `<yourfirstname>_dev` branch (and onto any of your other wip branches). You will receive notifications for when it is time to do this.

## Useful git Commands

NOTE: these steps are not in any chronological order.


### Setting up your branch(s)

To create a new branch (e.g., from your dev branch):

```
git branch <branch_name>
``` 

To checkout an existing branch:

```
git checkout <branch_name>
```

### Rebase

I find interactive rebase useful:

```
git rebase -i HEAD~n  # replace `n` with the number of commits you want to look back on
```
