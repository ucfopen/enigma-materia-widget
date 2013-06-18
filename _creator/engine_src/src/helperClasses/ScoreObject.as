/* See the file "LICENSE.txt" for the full license governing this code. */
package helperClasses
{
	public class ScoreObject
	{
		/**
		 *  Current score for this question. Is undefined by default.
		 */
		public var score:Number;
		/**
		 *  Total score available for this question. Is 100 by default.
		 */
		public var avail:int;
		public function ScoreObject(score:Number = undefined, avail:int = 100)
		{
			this.score = score;
			this.avail = avail;
		}
	}
}