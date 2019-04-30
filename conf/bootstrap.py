# Bootstrap the Sentry environment
import os

from sentry.conf.server import env
from sentry.utils.runner import configure
configure()

# Do something crazy
from sentry.models import (
    Team, Project, ProjectKey, User, Organization, OrganizationMember,
    OrganizationMemberTeam, Option
)

organization = Organization.objects.filter(id=1)[0]
team = Team.objects.filter(id=1)[0]

user = User()
user.username = env('AUTH_LOGIN')
user.email = env('AUTH_EMAIL')
user.is_superuser = True
user.set_password(env('AUTH_PASSWORD'))
user.save()

member = OrganizationMember.objects.create(
    organization=organization,
    user=user,
    role='owner',
)

project = Project()
project.slug = 'Default'
project.platform = 'php'
project.name = 'Default'
project.organization = organization
project.save()

project.add_team(team)

OrganizationMemberTeam.objects.create(
    organizationmember_id=member.id,
    team_id=team.id,
)

Option.objects.create(key='mail.use-tls', value='0')
Option.objects.create(key='mail.username', value='test')
Option.objects.create(key='mail.port', value='1234')
Option.objects.create(key='mail.host', value='localhost')
Option.objects.create(key='mail.password', value='password')
Option.objects.create(key='mail.from', value='from@admin.com')
Option.objects.create(key='system.admin-email', value=user.email)
Option.objects.create(key='system.url-prefix', value='/')
Option.objects.create(key='auth.allow-registration', value=False)
Option.objects.create(key='beacon.anonymous', value=True)
Option.objects.create(key='sentry:version-configured', value='9.1')

key = ProjectKey.objects.filter(project=project)[0]
key.public_key = '5249ec00774a40dfbabc35c67cdc5f5b'
key.secret_key = '2135ce3394d74cd187435bc2fe270cbb'
key.save()

print "Project id: " + project.id
print "Public key: " + key.public_key
print "Secret key: " + key.secret_key
