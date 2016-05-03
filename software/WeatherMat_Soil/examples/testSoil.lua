-- # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- # THE SOFTWARE.
-- import logging
-- import time

package.cpath = package.cpath .. ';../src/sht1x/?.so'

local sht1x = require "sht1x"
result, temp, humidity, dewpoint = readsht1x()

print (string.format('Temperature = %f  Humidity = %f  DewPoint = %f', temp, humidity, dewpoint))






