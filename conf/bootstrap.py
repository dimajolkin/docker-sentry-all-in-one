# Bootstrap the Sentry environment
from sentry.utils.runner import configure
configure()

# Do something crazy
from sentry.models import (
    Team, Project, ProjectKey, User, Organization, OrganizationMember,
    OrganizationMemberTeam
)

organization = Organization()
organization.name = 'MyOrg'
organization.save()

team = Team()
team.name = 'Sentry'
team.organization = organization
team.save()

project = Project()
project.team = team
project.add_team(team)
project.slug = 'php'
project.platform = 'php'
project.name = 'Default'
project.organization = organization
project.save()

user = User()
user.username = 'admin'
user.email = 'admin@localhost'
user.is_superuser = True
user.set_password('admin')
user.save()

member = OrganizationMember.objects.create(
    organization=organization,
    user=user,
    role='owner',
)

OrganizationMemberTeam.objects.create(
    organizationmember=member,
    team=team,
)

key = ProjectKey.objects.filter(project=project)[0]
print 'SENTRY_DSN = "%s"' % (key.get_dsn(),)