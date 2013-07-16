<?php
/**
 * Materia
 * It's a thing
 *
 * @package	    Materia
 * @version    1.0
 * @author     UCF New Media
 * @copyright  2011 New Media
 * @link       http://kogneato.com
 */


/**
 * NEEDS DOCUMENTATION
 *
 * The widget managers for the Materia package.
 *
 * @package	    Main
 * @subpackage  scoring
 * @category    Modules
  * @author      ADD NAME HERE
 */

namespace Materia;

class Score_Modules_EnigmaGS extends Score_Module
{

	private $new_logs = [];
	private $q_ids = null;

	public function check_answer($log)
	{
		if (isset($this->questions[$log->item_id]))
		{
			$q = $this->questions[$log->item_id];
			foreach ($q->answers as $answer)
			{
				if ($log->text == $answer['text']) return $answer['value'];
			}
		}

		return 0;
	}

	protected function handle_log_question_answered($log)
	{
		if ($this->q_ids == null) $this->q_ids = array_keys($this->questions);

		$this->total_questions++;
		$this->verified_score += $this->check_answer($log); // score the question and add it to the total

		// find current log's index from original quetion's array and add to new array
		$q_index = array_search($log->item_id, $this->q_ids);
		$this->new_logs[$q_index] = $log;
	}

	protected function calculate_score()
	{
		ksort($this->new_logs);
		$this->logs = $this->new_logs;

		$global_mod = array_sum($this->global_modifiers);
		// if ( ! is_numeric($mod)) $mod = 0;
		if ($this->total_questions > 0)
		{
			$points = $this->verified_score + $global_mod * $this->total_questions;
			$this->calculated_percent = $points / $this->total_questions;
		}
		else
		{
			$points = 100 + $this->verified_score + $global_mod;
			$this->calculated_percent = $points;
		}
		if ($this->calculated_percent < 0) $this->calculated_percent = 0;
	}
}