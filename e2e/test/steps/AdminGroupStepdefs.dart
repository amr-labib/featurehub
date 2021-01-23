import 'package:app_singleapp/shared.dart';
import 'package:app_singleapp/superuser_common.dart';
import 'package:app_singleapp/user_common.dart';
import 'package:mrapi/api.dart';
import 'package:ogurets/ogurets.dart';
import 'package:openapi_dart_common/openapi.dart';

class AdminGroupStepdefs {
  final SuperuserCommon common;
  final UserCommon userCommon;
  final Shared shared;

  AdminGroupStepdefs(this.common, this.shared, this.userCommon);

  @Then(r'there is a admin group called {string} in portfolio {string}')
  void thereIsAAdminGroupCalled(String groupName, String portfolioName) async {
    await common.initialize();

    var portfolio = await userCommon.findExactPortfolio(portfolioName,
        portfolioServiceApi: common.portfolioService);

    assert(portfolio != null, 'No portfolio by name $portfolioName');
    List<Group> groups =
        await common.groupService.findGroups(portfolio.id, filter: groupName);

    assert(
        null !=
            groups.firstWhere((g) => g.admin && g.name == groupName,
                orElse: () => null),
        'Cannot find admin group name $groupName');
  }

  @And(
      r'I ensure the {string} user is added to the portfolio group {string} for portfolio {string}')
  void iEnsureTheUserIsAddedToThePortfolioGroupForPortfolio(
      String email, String groupName, String portfolioName) async {
    await common.initialize();

    var portfolio = await userCommon.findExactPortfolio(portfolioName,
        portfolioServiceApi: common.portfolioService);

    assert(portfolio != null, 'No portfolio by name $portfolioName');

    var group = await userCommon.findExactGroup(groupName, portfolio.id,
        groupServiceApi: common.groupService);
    assert(group != null, 'You havent created the group $groupName yet');

    var person = await userCommon.findExactEmail(email,
        personServiceApi: common.personService);
    assert(person != null, 'Cannot find person by email $email');

    try {
      await common.groupService.addPersonToGroup(group.id, person.id.id);
    } on ApiException catch (e) {
      print("duplicate, which is ok $e");
    }
  }

  @And(r'I ensure the following group setup exists:')
  void iEnsureTheFollowingGroupSetupExists(GherkinTable table) async {
    assert(shared.portfolio != null, 'Portfolio exists');
    assert(shared.application != null, 'Application exists');

    for (var g in table) {
      final group =
          await userCommon.findExactGroup(g["groupName"], shared.portfolio.id);
      if (group == null) {
        await userCommon.groupService
            .createGroup(shared.portfolio.id, Group()..name = g["groupName"]);
      }
    }
  }

  @And(
      r'I ensure the permission {string} is added to the group {string} to environment {string}')
  void iEnsureThePermissionIsAddedToTheGroup(
      String perm, String groupName, String envName) async {
    assert(shared.portfolio != null, 'Portfolio exists');
    assert(shared.application != null, 'Application exists');

    final group =
        await userCommon.findExactGroup(groupName, shared.portfolio.id);
    assert(group != null, 'the group $groupName must exist already');

    final env =
        await userCommon.findExactEnvironment(envName, shared.application.id);
    assert(env != null, 'env must exist and doesnt $envName');

    var er = group.environmentRoles
        .firstWhere((er) => er.environmentId == env.id, orElse: () => null);
    if (er == null) {
      er = EnvironmentGroupRole()
        ..environmentId = env.id
        ..groupId = group.id;
      group.environmentRoles.add(er);
    }
    final roleType = RoleTypeExtension.fromJson(perm);
    if (!er.roles.contains(roleType)) {
      er.roles.add(roleType);
    }
    await userCommon.groupService.updateGroup(group.id, group);
  }
}
