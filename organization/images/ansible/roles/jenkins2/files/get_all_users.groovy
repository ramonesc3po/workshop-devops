import hudson.model.User
import jenkins.model.Jenkins
def realm = Jenkins.getInstance().getSecurityRealm()
def users = realm.getAllUsers()
for (User u : users) {
    def userid = u.getId()
    println(userid + " ")
}
